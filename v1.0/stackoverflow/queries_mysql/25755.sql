
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        RANK() OVER (ORDER BY COUNT(c.Id) DESC) AS CommentRank
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
    GROUP BY
        p.Id,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate
),
TopRatedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM
        RankedPosts rp
    WHERE
        rp.CommentRank <= 10
),
TagSummary AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL
        SELECT 9 UNION ALL SELECT 10 UNION ALL SELECT 11 UNION ALL SELECT 12 UNION ALL
        SELECT 13 UNION ALL SELECT 14 UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL
        SELECT 17 UNION ALL SELECT 18 UNION ALL SELECT 19 UNION ALL SELECT 20
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        @row_number := @row_number + 1 AS TagRank
    FROM
        TagSummary ts, (SELECT @row_number := 0) r
    ORDER BY
        ts.PostCount DESC
)
SELECT
    ttp.Title,
    ttp.CommentCount,
    ttp.UpVotes,
    ttp.DownVotes,
    tt.TagName
FROM
    TopRatedPosts ttp
JOIN
    TopTags tt ON ttp.Tags LIKE CONCAT('%', tt.TagName, '%')
ORDER BY
    ttp.UpVotes DESC,
    ttp.CommentCount DESC;
