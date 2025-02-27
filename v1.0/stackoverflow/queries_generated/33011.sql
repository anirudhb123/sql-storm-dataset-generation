WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.ViewCount IS NOT NULL
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(t.TagName, 'Uncategorized') AS Tag
    FROM 
        Posts p
    LEFT JOIN 
        LATERAL unnest(string_to_array(p.Tags, '>')) AS t(Tag) ON TRUE
),
PostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        pt.Tag,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.AnswerCount, pt.Tag
),
TopPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.ViewCount DESC) AS PopularityRank
    FROM 
        PostStatistics ps
    WHERE 
        ps.Rank = 1  -- Get highest scored post for each type
)
SELECT 
    u.DisplayName,
    u.Reputation,
    p.Title,
    p.ViewCount,
    p.CommentCount,
    p.UpVoteCount,
    p.Tag,
    COALESCE(TH.LastEdited, 'Never') AS LastEdited
FROM 
    TopPosts p
JOIN 
    Users u ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        PostId,
        MAX(LastEditDate) AS LastEdited
    FROM 
        Posts
    GROUP BY 
        PostId
) TH ON TH.PostId = p.PostId
WHERE 
    u.Reputation > 1000  -- Assuming we are only interested in users with high reputation
ORDER BY 
    p.PopularityRank, 
    p.ViewCount DESC
LIMIT 10;

-- Ensure to check for NULL logic by filtering users with NULL location.

