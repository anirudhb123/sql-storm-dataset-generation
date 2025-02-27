
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS TagsArray,
        (SELECT GROUP_CONCAT(DISTINCT u.DisplayName ORDER BY u.DisplayName SEPARATOR ', ') 
         FROM Users u 
         JOIN Votes v ON v.UserId = u.Id 
         WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotedUsers
    FROM Posts p
    LEFT JOIN Comments c ON c.PostId = p.Id
    LEFT JOIN (
        SELECT DISTINCT 
            unnest(string_to_array(p.Tags, '><')) AS TagName, p.Id 
        FROM Posts p
    ) AS t ON TRUE
    WHERE p.CreationDate >= CAST('2024-10-01' AS DATE) - INTERVAL 30 DAY 
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
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
LEFT JOIN PopularTags pt ON FIND_IN_SET(pt.TagName, rp.TagsArray) > 0
ORDER BY rp.CreationDate DESC, ps.Score DESC;
