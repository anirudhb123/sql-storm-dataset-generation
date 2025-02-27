
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime)) AND
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, u.DisplayName
),
PopularTags AS (
    SELECT 
        value AS Tag
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(Tags, ',')
    WHERE 
        CreationDate >= DATEADD(year, -1, CAST('2024-10-01 12:34:56' AS datetime))
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes,
    pt.Tag AS PopularTag
FROM 
    RankedPosts rp
CROSS JOIN 
    (SELECT TOP 5 Tag FROM PopularTags GROUP BY Tag ORDER BY COUNT(*) DESC) pt
WHERE 
    rp.PostRank <= 10 
ORDER BY 
    rp.Score DESC, 
    pt.Tag;
