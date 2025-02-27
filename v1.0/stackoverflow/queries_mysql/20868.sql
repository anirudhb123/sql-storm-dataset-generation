
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(a.OwnerDisplayName, 'Community User') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        (SELECT AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) FROM Votes v WHERE v.PostId = p.Id) AS AverageUpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.AcceptedAnswerId = a.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 MONTH)
    GROUP BY 
        p.Id, a.OwnerDisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags)
    -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        COUNT(*) DESC
    LIMIT 5
),
PostSummary AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.PostRank,
        pt.Tag AS PopularTag,
        rp.CommentCount,
        rp.AverageUpVotes,
        rp.DownVoteCount
    FROM 
        RankedPosts rp
    JOIN 
        PopularTags pt ON rp.Title LIKE CONCAT('%', pt.Tag, '%')
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    CASE 
        WHEN ps.OwnerDisplayName IS NULL THEN 'Unknown Owner' 
        ELSE ps.OwnerDisplayName 
    END AS OwnerDisplayName,
    ps.PostRank,
    ps.PopularTag,
    ps.CommentCount,
    ps.AverageUpVotes,
    ps.DownVoteCount,
    CASE 
        WHEN ps.DownVoteCount > ps.AverageUpVotes THEN 'Needs Improvement'
        WHEN ps.Score > 100 THEN 'Highly Engaged'
        ELSE 'Moderately Engaged'
    END AS EngagementLevel
FROM 
    PostSummary ps
WHERE 
    ps.PostRank <= 3
ORDER BY 
    ps.Score DESC, ps.ViewCount DESC
LIMIT 10;
