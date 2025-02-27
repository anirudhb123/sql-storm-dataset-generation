
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        LEN(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags))) - LEN(REPLACE(REPLACE(TRIM(BOTH '>' FROM TRIM(BOTH '<' FROM p.Tags)), '><', ''), '>', '')) AS TagCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM
        Posts AS p
    LEFT JOIN
        Comments AS c ON p.Id = c.PostId
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY
        p.Id, p.Title, p.Body
),
PostTypeStatistics AS (
    SELECT
        pt.Name AS PostType,
        AVG(rp.CommentCount) AS AvgComments,
        AVG(rp.TagCount) AS AvgTags
    FROM
        RankedPosts AS rp
    JOIN
        PostTypes AS pt ON rp.PostId IN (
            SELECT Id FROM Posts WHERE PostTypeId = pt.Id
        )
    GROUP BY
        pt.Name
),
MostActiveUsers AS (
    SELECT
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM
        Users AS u
    JOIN
        Posts AS p ON u.Id = p.OwnerUserId
    GROUP BY
        u.DisplayName
    ORDER BY
        PostCount DESC
)
SELECT TOP 10
    pts.PostType,
    pts.AvgComments,
    pts.AvgTags,
    mau.DisplayName AS MostActiveUser
FROM
    PostTypeStatistics AS pts
CROSS JOIN
    MostActiveUsers AS mau
ORDER BY
    pts.PostType;
