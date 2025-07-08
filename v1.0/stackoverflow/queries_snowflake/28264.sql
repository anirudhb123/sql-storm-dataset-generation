
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVoteType,
        LISTAGG(t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags) - 2), '>')) AS t
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01') 
    GROUP BY 
        p.Id, u.DisplayName, p.Body, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.*,
        RANK() OVER (ORDER BY rp.CommentCount DESC, rp.AverageVoteType DESC) AS Rank
    FROM 
        RankedPosts rp
    WHERE 
        LENGTH(rp.Tags) > 0 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Owner,
    fp.CommentCount,
    fp.AverageVoteType,
    fp.Tags,
    CASE 
        WHEN fp.Rank <= 10 THEN 'Top 10'
        WHEN fp.Rank <= 20 THEN 'Top 20'
        ELSE 'Below Top 20'
    END AS RankCategory
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Rank
LIMIT 50;
