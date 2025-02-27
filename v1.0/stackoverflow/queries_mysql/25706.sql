
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, p.Score, p.AnswerCount
),
PostDiversity AS (
    SELECT
        rp.PostId,
        COUNT(DISTINCT tg.TagName) AS UniqueTagsCount
    FROM
        RankedPosts rp
    CROSS JOIN
        (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', n.n), ',', -1)) AS Tag
         FROM (SELECT @row := @row + 1 AS n
               FROM (SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
                     UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n1,
               (SELECT @row := 0) n2
              ) n) AS tag
    INNER JOIN
        Tags tg ON tg.TagName = tag.Tag
    GROUP BY
        rp.PostId
),
ResultSet AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.Score,
        rp.AnswerCount,
        rp.CommentCount,
        pd.UniqueTagsCount,
        DENSE_RANK() OVER (ORDER BY rp.Score DESC) AS ScoreRank
    FROM
        RankedPosts rp
    JOIN
        PostDiversity pd ON rp.PostId = pd.PostId
    WHERE
        rp.rn = 1
)

SELECT
    rs.PostId,
    rs.Title,
    rs.ViewCount,
    rs.Score,
    rs.AnswerCount,
    rs.CommentCount,
    rs.UniqueTagsCount,
    rs.ScoreRank,
    CASE 
        WHEN rs.UniqueTagsCount >= 5 THEN 'Highly Diverse'
        WHEN rs.UniqueTagsCount BETWEEN 3 AND 4 THEN 'Moderately Diverse'
        ELSE 'Low Diversity'
    END AS TagDiversity
FROM
    ResultSet rs
WHERE
    rs.ScoreRank <= 100
ORDER BY
    rs.Score DESC, rs.ViewCount DESC;
