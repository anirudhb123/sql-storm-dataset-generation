WITH RecursiveUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        1 AS PostLevel
    FROM Users u
    WHERE u.Views > 50
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        rus.PostLevel + 1
    FROM Users u
    JOIN RecursiveUserStats rus ON u.Id = rus.UserId
    WHERE rus.PostLevel < 5
),
PostVoteCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(pvc.VoteCount, 0) AS TotalVotes,
        COALESCE(pvc.UpVotes, 0) AS TotalUpVotes,
        COALESCE(pvc.DownVotes, 0) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN PostVoteCounts pvc ON p.Id = pvc.PostId
    WHERE p.ViewCount > 100 AND (p.Score > 0 OR p.AnswerCount > 0)
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(pd.Id) AS PostCount,
        SUM(pd.Score) AS TotalScore,
        AVG(pd.ViewCount) AS AvgViewCount,
        MAX(pd.PostRank) AS MaxPostRank
    FROM Users u
    LEFT JOIN PostDetails pd ON u.Id = pd.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.AvgViewCount,
    ups.MaxPostRank,
    rus.Reputation,
    rus.Views,
    rus.UpVotes,
    rus.DownVotes
FROM UserPostStats ups
JOIN RecursiveUserStats rus ON ups.UserId = rus.UserId
WHERE ups.PostCount > 5
ORDER BY ups.TotalScore DESC, ups.PostCount ASC;
