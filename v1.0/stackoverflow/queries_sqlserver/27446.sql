
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsArray,
        (SELECT STRING_AGG(DISTINCT u.DisplayName, ', ') 
         FROM Users u 
         JOIN Votes v ON v.UserId = u.Id 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotedUsers
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    CROSS APPLY STRING_SPLIT(p.Tags, '><') AS t
    WHERE p.CreationDate >= CAST('2024-10-01' AS DATE) - 30 
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' + t.TagName + '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName
    FROM Posts p
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    JOIN Users u ON p.OwnerUserId = u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.CommentCount,
    rp.TagsArray,
    rp.UpVotedUsers,
    ps.ViewCount,
    ps.Score,
    ps.PostType,
    ps.OwnerDisplayName,
    pt.TagName AS PopularTag
FROM RecentPosts rp
JOIN PostStats ps ON rp.PostId = ps.PostId
LEFT JOIN PopularTags pt ON pt.TagName IN (SELECT value FROM STRING_SPLIT(rp.TagsArray, ', '))
ORDER BY rp.CreationDate DESC, ps.Score DESC;
