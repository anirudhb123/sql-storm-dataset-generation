
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        @row_number := IF(@prev_postTypeId = p.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_postTypeId := p.PostTypeId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_postTypeId := NULL) AS init
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    INNER JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        t.TagName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    pt.TagName,
    pt.PostCount,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10'
        ELSE 'Other'
    END AS PostRankCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularTags pt ON pt.PostCount > 5
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
