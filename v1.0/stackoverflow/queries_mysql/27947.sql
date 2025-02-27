
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @rownum := @rownum + 1 AS Rank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    JOIN (
        SELECT
            DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
        FROM
            Posts p
        JOIN
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) AS t ON t.TagName IS NOT NULL
    JOIN (SELECT @rownum := 0) r
    WHERE
        p.PostTypeId = 1 
    GROUP BY
        p.Id, p.Title, p.CreationDate, u.DisplayName
),
PopularTags AS (
    SELECT
        t.TagName AS PopularTag
    FROM
        Posts p
    JOIN (
        SELECT
            DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
        FROM
            Posts p
        JOIN
            (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
             UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) AS t ON t.TagName IS NOT NULL
    GROUP BY
        t.TagName
    ORDER BY
        COUNT(*) DESC
    LIMIT 10 
),
TagStatistics AS (
    SELECT
        pt.PopularTag,
        COUNT(rp.PostId) AS PostsCount,
        SUM(rp.UpVoteCount) AS TotalUpVotes,
        SUM(rp.DownVoteCount) AS TotalDownVotes,
        AVG(rp.CommentCount) AS AverageComments
    FROM
        PopularTags pt
    LEFT JOIN
        RankedPosts rp ON FIND_IN_SET(pt.PopularTag, rp.Tags) > 0
    GROUP BY
        pt.PopularTag
)
SELECT
    ts.PopularTag,
    ts.PostsCount,
    ts.TotalUpVotes,
    ts.TotalDownVotes,
    ts.AverageComments,
    CONCAT('Tag: ', ts.PopularTag, 
           ' | Total Posts: ', ts.PostsCount, 
           ' | UpVotes: ', ts.TotalUpVotes,
           ' | DownVotes: ', ts.TotalDownVotes,
           ' | Average Comments: ', ROUND(ts.AverageComments, 2)) AS Summary
FROM
    TagStatistics ts
ORDER BY
    ts.PostsCount DESC;
