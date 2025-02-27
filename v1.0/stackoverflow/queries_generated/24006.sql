WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
PostActivity AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(ph.CreationDate, NULL) AS LastEditDate,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (4, 5, 6)) AS EditCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM RankedPosts rp
    LEFT JOIN PostHistory ph ON rp.PostId = ph.PostId
    LEFT JOIN Votes v ON rp.PostId = v.PostId
    GROUP BY rp.PostId, rp.Title, rp.CreationDate, rp.ViewCount, rp.AnswerCount, ph.CreationDate
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.ViewCount,
    pa.AnswerCount,
    pa.EditCount,
    pa.UpvoteCount,
    pa.DownvoteCount,
    CASE 
        WHEN pa.EditCount > 5 THEN 'Highly Edited'
        WHEN pa.EditCount BETWEEN 1 AND 5 THEN 'Edited'
        ELSE 'Not Edited'
    END AS EditStatus,
    pa.LastEditDate,
    COALESCE(NULLIF(pa.LastEditDate, pa.CreationDate), 'Never Edited') AS EditDateStatus
FROM PostActivity pa
WHERE 
    pa.ViewCount > 100 AND 
    pa.AnswerCount IS NOT NULL AND
    pa.AnswerCount > (
        SELECT AVG(AnswerCount) FROM (
            SELECT AnswerCount FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year'
        ) AS sub
    )
ORDER BY pa.ViewCount DESC
LIMIT 50;

-- Additional Complexity: Fetching data about users who contributed to these posts
WITH UserPostEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT pa.PostId) AS PostsEngaged,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotesGiven,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotesGiven
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    JOIN Posts p ON v.PostId = p.Id
    JOIN PostActivity pa ON pa.PostId = p.Id
    WHERE pa.ViewCount > 100
    GROUP BY u.Id, u.DisplayName
    HAVING SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) > 0
)
SELECT 
    upe.UserId,
    upe.DisplayName,
    upe.PostsEngaged,
    upe.TotalUpvotesGiven,
    upe.TotalDownvotesGiven,
    CASE 
        WHEN upe.TotalUpvotesGiven > upe.TotalDownvotesGiven THEN 'Positive Contributor'
        WHEN upe.TotalUpvotesGiven < upe.TotalDownvotesGiven THEN 'Negative Contributor'
        ELSE 'Neutral Contributor'
    END AS ContributorType
FROM UserPostEngagement upe
ORDER BY upe.PostsEngaged DESC
LIMIT 20;
