WITH RankedPosts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.Body,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           u.DisplayName AS OwnerDisplayName,
           SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
           SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
           COUNT(c.Id) AS CommentCount,
           ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopRankedPosts AS (
    SELECT PostId, Title, Body, CreationDate, Score, ViewCount, OwnerDisplayName, UpVotes, DownVotes, CommentCount
    FROM RankedPosts
    WHERE rn = 1
    ORDER BY Score DESC, CreationDate DESC
    LIMIT 10
),
PostTags AS (
    SELECT p.Id AS PostId,
           STRING_AGG(t.TagName, ', ') AS TagsList
    FROM Posts p
    JOIN Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE p.PostTypeId = 1
    GROUP BY p.Id
)
SELECT t.Title,
       t.CreationDate,
       t.OwnerDisplayName,
       t.Score,
       t.ViewCount,
       t.UpVotes,
       t.DownVotes,
       t.CommentCount,
       pt.TagsList
FROM TopRankedPosts t
LEFT JOIN PostTags pt ON t.PostId = pt.PostId
ORDER BY t.Score DESC, t.CreationDate DESC;
