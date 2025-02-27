
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
    CROSS APPLY 
        (SELECT value AS TagName FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS t
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
        v.CreationDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 30 DAY)
    GROUP BY 
        v.PostId
), 
PostHistories AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ',') AS ChangeTypes
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
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
