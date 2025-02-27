WITH RecursivePostPaths AS (
    -- Get all answers and their respective questions recursively
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        1 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.ParentId,
        rp.Level + 1,
        CAST(rp.Path + ' -> ' + a.Title AS VARCHAR(MAX)) AS Path
    FROM Posts a
    JOIN RecursivePostPaths rp ON rp.PostId = a.ParentId
    WHERE a.PostTypeId = 2 -- Only answers
),
PostVoteStatistics AS (
    -- Aggregate votes by post and calculate a score for posts
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 4 THEN 1 ELSE 0 END), 0) AS OffensiveVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.PostTypeId IN (1, 2) -- Questions and Answers
    GROUP BY p.Id, p.Title
),
UserStatistics AS (
    -- Calculate total reputation and badge counts per user
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgePoints,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
RankedPosts AS (
    -- Ranking posts based on their score and filtering down to users of interest
    SELECT 
        p.Id,
        p.Title,
        (ups.UpVotes - downs.DownVotes) AS Score,
        ROW_NUMBER() OVER (ORDER BY (ups.UpVotes - downs.DownVotes) DESC) AS Rank,
        p.OwnerUserId
    FROM Posts p
    JOIN PostVoteStatistics ups ON p.Id = ups.PostId
    LEFT JOIN PostVoteStatistics downs ON p.Id = downs.PostId
    WHERE p.PostTypeId = 1 -- Only questions
)
-- Final selection, combining user statistics with ranked posts and post paths
SELECT 
    r.Title AS PostTitle,
    u.DisplayName AS User,
    r.Score,
    r.Rank,
    pp.Path AS AnswerPath,
    pp.Level AS AnswerLevel
FROM RankedPosts r
JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN RecursivePostPaths pp ON pp.PostId = r.Id
WHERE r.Score > 0
ORDER BY r.Score DESC, r.Rank ASC;
