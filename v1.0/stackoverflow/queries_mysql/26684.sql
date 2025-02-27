
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Tags,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS Rank,
        GROUP_CONCAT(DISTINCT CONCAT(u.DisplayName, ' (', u.Reputation, ')') SEPARATOR ', ') AS Commenters
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON c.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Tags, p.ViewCount
),
RecentQuestions AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Tags,
        rp.ViewCount,
        rp.CommentCount,
        rp.Commenters
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1 AND rp.CreationDate >= NOW() - INTERVAL 30 DAY
),
KeywordTagCount AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(t.TagName, ',', n.n), ',', -1) AS Tag,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n
    ON CHAR_LENGTH(t.TagName) - CHAR_LENGTH(REPLACE(t.TagName, ',', '')) >= n.n - 1
    GROUP BY 
        Tag
)
SELECT 
    rq.Title,
    rq.CreationDate,
    rq.ViewCount,
    rq.CommentCount,
    rq.Commenters,
    kt.Tag,
    kt.PostCount
FROM 
    RecentQuestions rq
LEFT JOIN 
    KeywordTagCount kt ON rq.Tags LIKE CONCAT('%', kt.Tag, '%')
ORDER BY 
    rq.ViewCount DESC, rq.CreationDate DESC;
