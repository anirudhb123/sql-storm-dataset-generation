WITH RECURSIVE UserVotingStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COALESCE(SUM(CASE WHEN P.Score >= 0 THEN 1 ELSE 0 END), 0) AS PositiveScorePosts,
        COALESCE(SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END), 0) AS NegativeScorePosts
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName
),
ActivityTimeline AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        P.CreationDate,
        P.Title,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY P.CreationDate DESC) AS RowNum
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.CreationDate >= current_date - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.UpVotes,
        U.DownVotes,
        U.TotalPosts,
        U.PositiveScorePosts,
        U.NegativeScorePosts,
        AT.Title,
        AT.CreationDate,
        AT.ViewCount
    FROM 
        UserVotingStats U
    JOIN 
        ActivityTimeline AT ON U.UserId = AT.UserId
    WHERE 
        U.TotalPosts > 5 AND (U.UpVotes - U.DownVotes) > 10
),
RecentBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    WHERE 
        B.Date >= current_date - INTERVAL '30 days'
    GROUP BY 
        B.UserId
),
UserWithBadges AS (
    SELECT 
        TU.UserId,
        TU.DisplayName,
        TB.BadgeCount,
        TU.UpVotes,
        TU.DownVotes,
        TU.TotalPosts,
        TU.PositiveScorePosts,
        TU.NegativeScorePosts,
        TU.Title,
        TU.CreationDate,
        TU.ViewCount
    FROM 
        TopUsers TU
    LEFT JOIN 
        RecentBadges TB ON TU.UserId = TB.UserId
)

SELECT 
    U.*,
    COALESCE(B.BadgeCount, 0) AS BadgeCount,
    CASE 
        WHEN U.PositiveScorePosts > U.NegativeScorePosts THEN 'Positive Contributor'
        WHEN U.NegativeScorePosts > U.PositiveScorePosts THEN 'Needs Improvement'
        ELSE 'Neutral'
    END AS ContributorStatus
FROM 
    UserWithBadges U
ORDER BY 
    U.UpVotes DESC, U.ViewCount DESC
LIMIT 10;
