
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
        p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL '1 month'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, a.OwnerDisplayName
),
PopularTags AS (
    SELECT 
        value AS Tag
    FROM 
        STRING_SPLIT(Tags, '><') 
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        value
    ORDER BY 
        COUNT(*) DESC
    OFFSET 0 ROWS 
    FETCH NEXT 5 ROWS ONLY
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
        PopularTags pt ON rp.Title LIKE '%' + pt.Tag + '%'
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
OFFSET 0 ROWS 
FETCH NEXT 10 ROWS ONLY;
