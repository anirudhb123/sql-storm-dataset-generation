
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(COALESCE(VOT.UpVotes, 0)) AS TotalUpVotes,
        SUM(COALESCE(VOT.DownVotes, 0)) AS TotalDownVotes,
        @rank := @rank + 1 AS ScoreRank
    FROM 
        Posts P
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
            COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) VOT ON P.Id = VOT.PostId,
    (SELECT @rank := 0) r
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.OwnerUserId
),
UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        UB.BadgeCount,
        PS.PostCount,
        PS.TotalScore,
        PS.ScoreRank,
        (PS.TotalUpVotes - PS.TotalDownVotes) AS NetVotes
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        PostStats PS ON U.Id = PS.OwnerUserId
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        BadgeCount,
        PostCount,
        TotalScore,
        ScoreRank,
        NetVotes
    FROM 
        UserPostStats
    WHERE 
        ScoreRank <= 10
)
SELECT 
    TU.DisplayName,
    TU.BadgeCount,
    TU.PostCount,
    TU.TotalScore,
    TU.NetVotes,
    CASE 
        WHEN TU.NetVotes IS NULL THEN 'No Votes'
        WHEN TU.NetVotes > 50 THEN 'Highly Voted'
        WHEN TU.NetVotes BETWEEN 20 AND 50 THEN 'Moderately Voted'
        ELSE 'Low Votes'
    END AS VotingCategory,
    COALESCE(GROUP_CONCAT(DISTINCT T.TagName), '') AS TagsContributed
FROM 
    TopUsers TU
LEFT JOIN 
    Posts P ON TU.UserId = P.OwnerUserId
LEFT JOIN 
    (
        SELECT 
            PostId, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '><', numbers.n), '><', -1) TagName
        FROM 
            Posts P
        JOIN 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
             UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 
             UNION ALL SELECT 10) numbers ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '><', '')) >= numbers.n - 1
    ) T ON P.Id = T.PostId
GROUP BY 
    TU.UserId, TU.DisplayName, TU.BadgeCount, TU.PostCount, TU.TotalScore, TU.NetVotes
ORDER BY 
    TU.TotalScore DESC, TU.BadgeCount DESC;
