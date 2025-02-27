WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COALESCE(json_agg(DISTINCT t.TagName) FILTER (WHERE t.TagName IS NOT NULL), '[]') AS Tags,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.OwnerUserId
),
TopRankedPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE Rank <= 5
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        CASE 
            WHEN u.Reputation < 100 THEN 'Newbie' 
            WHEN u.Reputation BETWEEN 100 AND 999 THEN 'Intermediate' 
            ELSE 'Veteran' 
        END AS UserCategory
    FROM 
        Users u
)
SELECT 
    trp.PostId,
    trp.Title,
    trp.Score,
    trp.ViewCount,
    trp.CreationDate,
    ur.Reputation,
    ur.UserCategory,
    CASE 
        WHEN trp.Upvotes - trp.Downvotes > 0 THEN 'Positive Feedback' 
        WHEN trp.Upvotes - trp.Downvotes < 0 THEN 'Negative Feedback' 
        ELSE 'Neutral Feedback' 
    END AS Feedback,
    CASE 
        WHEN trp.Tags IS NULL OR trp.Tags = '[]' THEN 'No Tags Available' 
        ELSE trp.Tags 
    END AS PostTags
FROM 
    TopRankedPosts trp
JOIN 
    Users u ON trp.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.Id
WHERE 
    trp.ViewCount > 100 OR trp.Score > 50
ORDER BY 
    trp.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additional complexity with NULL handling and outer joins
SELECT 
    p.Id,
    p.Title,
    COALESCE(ph.Comment, 'No comments') AS PostComment,
    COALESCE(v.VoteTypeId, 0) AS LastVoteTypeId,
    CASE 
        WHEN ph.CreationDate IS NULL THEN 'No History'
        ELSE to_char(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS')
    END AS LastHistoryDate
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    p.CreationDate > (CURRENT_DATE - INTERVAL '30 days')
    AND (v.VoteTypeId IS NULL OR v.VoteTypeId = 2)
ORDER BY 
    p.CreationDate DESC;

