WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) -- Considering only upvotes and downvotes
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Rank,
        COALESCE(SUM(CASE WHEN bh.PostHistoryTypeId = 10 THEN 1 ELSE 0 END), 0) AS CloseCount,
        COUNT(DISTINCT b.UserId) AS BadgeCount -- Counting unique users who have badges related to the posts
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistory bh ON rp.PostId = bh.PostId
    LEFT JOIN 
        Badges b ON rp.PostId = b.UserId
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per type
    GROUP BY 
        rp.PostId
),
TopPostStats AS (
    SELECT 
        pd.*,
        CASE 
            WHEN pd.CloseCount > 0 THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus,
        CONCAT('Score: ', pd.Score, ', Votes: ', pd.VoteCount) AS ScoreVoteSummary
    FROM 
        PostDetails pd
)
SELECT 
    tps.*,
    COALESCE(linked.RelatedPostId, 'No Related Post') AS RelatedPostId
FROM 
    TopPostStats tps
LEFT JOIN 
    PostLinks linked ON tps.PostId = linked.PostId
WHERE 
    tps.PostStatus = 'Open'
ORDER BY 
    tps.CreationDate DESC
LIMIT 10;

-- Adding an additional section with unusual semantics checks
WITH UnusualSemanticCheck AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        CASE 
            WHEN STRING_AGG(DISTINCT t.TagName, ', ') IS NULL THEN 'No Tags'
            ELSE STRING_AGG(DISTINCT t.TagName, ', ')
        END AS AllTags
    FROM 
        Posts p
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS t (TagName) ON TRUE
    GROUP BY 
        p.Id
)
SELECT 
    usc.PostId,
    usc.Title,
    CASE 
        WHEN usc.AllTags = 'No Tags' THEN '[Tags Missing]'
        ELSE usc.AllTags
    END AS TagStatus
FROM 
    UnusualSemanticCheck usc
WHERE 
    usc.PostId NOT IN (SELECT RelatedPostId FROM PostLinks)
ORDER BY 
    usc.PostId DESC
LIMIT 5;
