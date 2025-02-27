WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Selecting only Questions

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        Level + 1
    FROM Posts p2
    INNER JOIN RecursivePosts rp ON p2.ParentId = rp.Id
)
SELECT 
    u.DisplayName AS Author,
    rp.Title AS QuestionTitle,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = rp.Id AND v2.VoteTypeId = 6) AS CloseVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS UserVoteRank
FROM RecursivePosts rp
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN Comments c ON rp.Id = c.PostId
LEFT JOIN Votes v ON rp.Id = v.PostId
GROUP BY u.DisplayName, rp.Title, rp.Id
HAVING COUNT(DISTINCT c.Id) > 5 
   AND SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
ORDER BY BadgeCount DESC, UpVotes DESC
LIMIT 20;

-- Getting the performance metrics for this query
EXPLAIN ANALYZE
WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 

    UNION ALL

    SELECT 
        p2.Id,
        p2.Title,
        p2.CreationDate,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        Level + 1
    FROM Posts p2
    INNER JOIN RecursivePosts rp ON p2.ParentId = rp.Id
)
SELECT 
    u.DisplayName AS Author,
    rp.Title AS QuestionTitle,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
    (SELECT COUNT(*) FROM Votes v2 WHERE v2.PostId = rp.Id AND v2.VoteTypeId = 6) AS CloseVotes,
    (SELECT COUNT(*) FROM Badges b WHERE b.UserId = u.Id) AS BadgeCount,
    ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY COUNT(DISTINCT v.Id) DESC) AS UserVoteRank
FROM RecursivePosts rp
LEFT JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN Comments c ON rp.Id = c.PostId
LEFT JOIN Votes v ON rp.Id = v.PostId
GROUP BY u.DisplayName, rp.Title, rp.Id
HAVING COUNT(DISTINCT c.Id) > 5 
   AND SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) > 10
ORDER BY BadgeCount DESC, UpVotes DESC
LIMIT 20;
