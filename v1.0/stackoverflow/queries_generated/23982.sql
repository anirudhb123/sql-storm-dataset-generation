WITH UserVoteCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 
            ELSE 0 
        END AS IsAccepted
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id, p.Title, p.ViewCount, p.CreationDate, p.OwnerUserId, p.AcceptedAnswerId
),
RecentPosts AS (
    SELECT *,
           CASE 
               WHEN TotalUpvotes = 0 THEN NULL
               ELSE ROUND((TotalUpvotes::decimal / NULLIF(TotalDownvotes, 0)) * 100, 2)
           END AS UpvoteToDownvoteRatio
    FROM PostAnalytics
)
SELECT 
    upc.UserId,
    upc.DisplayName,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(rp.ViewCount) AS TotalViews,
    AVG(rp.UpvoteToDownvoteRatio) AS AverageUpvoteToDownvoteRatio,
    STRING_AGG(DISTINCT rp.Title, '; ') AS RecentlyCreatedTitles
FROM UserVoteCounts upc
LEFT JOIN RecentPosts rp ON upc.UserId = rp.OwnerUserId 
GROUP BY upc.UserId, upc.DisplayName
HAVING AVG(rp.UpvoteToDownvoteRatio) IS NOT NULL
ORDER BY TotalViews DESC
FETCH FIRST 5 ROWS ONLY;
