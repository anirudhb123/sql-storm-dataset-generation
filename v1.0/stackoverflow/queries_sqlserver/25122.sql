
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        COUNT(DISTINCT t.Id) AS TagCount
    FROM
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '>') AS tag_name
    JOIN
        Tags t ON t.TagName = tag_name.value
    GROUP BY
        p.Id
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(p.Title, 'No Title') AS Title,
        pt.Name AS PostType,
        u.DisplayName AS Owner,
        p.CreationDate,
        p.ViewCount,
        pc.TagCount
    FROM
        Posts p
    JOIN
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        PostTagCounts pc ON p.Id = pc.PostId
    WHERE
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TopPostStats AS (
    SELECT
        PostId,
        Title,
        PostType,
        Owner,
        CreationDate,
        ViewCount,
        ROW_NUMBER() OVER (ORDER BY ViewCount DESC) AS Rank
    FROM
        PostDetails
)

SELECT
    tp.PostId,
    tp.Title,
    tp.PostType,
    tp.Owner,
    tp.CreationDate,
    tp.ViewCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM
    TopPostStats tp
WHERE
    tp.Rank <= 10
ORDER BY
    tp.Rank;
