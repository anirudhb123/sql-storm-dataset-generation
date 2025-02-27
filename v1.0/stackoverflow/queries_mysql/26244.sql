
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        U1.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    LEFT JOIN Users U1 ON p.OwnerUserId = U1.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT
            p.Id,
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
             UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
        INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    ) AS tag ON TRUE
    INNER JOIN Tags t ON tag.tag = t.TagName
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, U1.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TagPopularity AS (
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM
        Tags t
    LEFT JOIN Posts p ON t.Id = p.Id  
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        t.TagName
),
TopTags AS (
    SELECT
        TagName,
        PostCount,
        TotalViews,
        TotalScore,
        RANK() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM
        TagPopularity
    WHERE
        PostCount > 0
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.VoteCount,
    tt.TagName,
    tt.PostCount,
    tt.TotalViews,
    tt.TotalScore
FROM
    RankedPosts rp
JOIN
    TopTags tt ON FIND_IN_SET(tt.TagName, rp.Tags) > 0
WHERE
    rp.Rank <= 10  
ORDER BY
    rp.Score DESC, tt.TotalViews DESC;
