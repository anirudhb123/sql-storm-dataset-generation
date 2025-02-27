WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Filter for questions
),
PostStats AS (
    SELECT 
        PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,  -- Up votes
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes  -- Down votes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        PostId
),
HighlightedBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Class = 1  -- Gold badges
    GROUP BY 
        b.UserId
),
FinalData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        rb.BadgeNames,
        CASE 
            WHEN ps.UpVotes - ps.DownVotes > 0 THEN 'Positive'
            WHEN ps.UpVotes - ps.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostStats ps ON rp.PostId = ps.PostId
    LEFT JOIN 
        HighlightedBadges rb ON rp.PostId = rb.UserId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    CommentCount,
    UpVotes,
    DownVotes,
    COALESCE(BadgeNames, 'No Gold Badges') AS BadgeNames,
    Sentiment
FROM 
    FinalData
WHERE 
    rn <= 3  -- Only top 3 recent questions per user
ORDER BY 
    CreationDate DESC;
This SQL query retrieves recent questions from users, gathering statistics on comments, upvotes, and downvotes, while displaying gold badges earned by the users. It also includes sentiment analysis based on the difference between upvotes and downvotes. It combines multiple constructs and concepts such as CTEs, window functions, aggregates, and outer joins for a comprehensive and interesting analysis.
