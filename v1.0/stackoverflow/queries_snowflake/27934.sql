
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS Rank,
        LISTAGG(DISTINCT u.DisplayName, ', ') AS ContributingUsers
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 day' 
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.Tags, pt.Name
),
PostTagStats AS (
    SELECT 
        TRIM(value) AS Tag,
        COUNT(*) AS PostCount
    FROM 
        Posts p,
        LATERAL FLATTEN(input => SPLIT(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS value
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        Tag
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.Rank,
    rp.ContributingUsers,
    pts.PostCount AS TagPostCount
FROM 
    RankedPosts rp
JOIN 
    PostTagStats pts ON pts.Tag = TRIM(value)
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Rank, rp.Score DESC;
