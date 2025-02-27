
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        t.TagName,
        DENSE_RANK() OVER (PARTITION BY t.TagName ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
         FROM Posts p 
         JOIN (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
               UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 
               UNION SELECT 9 UNION SELECT 10) numbers 
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
        ) AS t ON t.TagName IS NOT NULL
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
), 
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate > (NOW() - INTERVAL 30 DAY)
    GROUP BY 
        v.PostId
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        GROUP_CONCAT(DISTINCT pht.Name) AS ChangeTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
), 
PostStats AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.ViewCount,
        COALESCE(rp.Upvotes, 0) AS Upvotes,
        COALESCE(rp.Downvotes, 0) AS Downvotes,
        ph.ChangeTypes,
        COALESCE(tp.Score + COALESCE(rp.Upvotes, 0) - COALESCE(rp.Downvotes, 0), tp.Score) AS AdjustedScore,
        tp.TagName,
        tp.TagRank
    FROM 
        TaggedPosts tp
    LEFT JOIN 
        RecentVotes rp ON tp.PostId = rp.PostId
    LEFT JOIN 
        PostHistories ph ON tp.PostId = ph.PostId
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.ChangeTypes,
    ps.AdjustedScore,
    CASE 
        WHEN ps.AdjustedScore IS NULL THEN 'Score not available' 
        WHEN ps.AdjustedScore < 0 THEN 'Needs improvement'
        WHEN ps.AdjustedScore BETWEEN 0 AND 50 THEN 'Moderate engagement'
        ELSE 'High engagement'
    END AS EngagementLevel 
FROM 
    PostStats ps
WHERE 
    EXISTS (
        SELECT 1 
        FROM PostStats ps2 
        WHERE ps2.TagRank <= 5 
        AND ps.TagName = ps2.TagName
    )
ORDER BY 
    ps.AdjustedScore DESC, 
    ps.ViewCount DESC 
LIMIT 20 OFFSET 10;
