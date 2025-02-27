
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Owner,
        COUNT(c.Id) AS CommentCount,
        AVG(v.VoteTypeId) AS AverageVoteType,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        LATERAL (
            SELECT 
                VALUE AS TagName
            FROM 
                STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>')
        ) AS t ON 1=1
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01') 
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
        LEN(rp.Tags) > 0 
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
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
