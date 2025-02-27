WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, 0 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Selecting higher reputation users to start the hierarchy

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate, uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id = (SELECT MAX(Id) FROM Users WHERE Reputation < uh.Reputation)  -- A hypothetical relationship for recursive hierarchy
),
PostSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
VoteSummary AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes, -- Summing upvotes
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes -- Summing downvotes
    FROM Votes v
    GROUP BY v.PostId
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        uh.Reputation,
        ps.PostCount,
        ps.TotalScore,
        ps.LastPostDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN uh.Reputation IS NULL THEN 'No Reputation' 
            WHEN uh.Level = 0 THEN 'New Member' 
            ELSE CAST(uh.Level AS VARCHAR) + ' Level User' 
        END AS UserLevel
    FROM Users u
    LEFT JOIN UserHierarchy uh ON u.Id = uh.Id
    LEFT JOIN PostSummary ps ON u.Id = ps.OwnerUserId
    LEFT JOIN VoteSummary vs ON ps.OwnerUserId = vs.PostId
)
SELECT 
    u.UserId, 
    u.DisplayName,
    u.Reputation,
    u.PostCount,
    u.TotalScore,
    u.LastPostDate,
    u.UpVotes,
    u.DownVotes,
    u.UserLevel
FROM UserPostDetails u
WHERE u.PostCount > 5  -- Filtering to show only users with more than 5 posts
ORDER BY u.TotalScore DESC, u.LastPostDate DESC
LIMIT 10  -- Limiting results to top 10 active users
This query creates a detailed user overview by using Common Table Expressions (CTEs) to recursively gather user reputation and their relationship, aggregate post data, and summarize vote counts. The final selection filters for users with more than five posts and orders them by their total scores and last post date.
