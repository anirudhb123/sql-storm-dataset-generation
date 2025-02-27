
WITH RecursivePostStats AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        MAX(COALESCE(P.LastActivityDate, P.CreationDate)) AS LastActiveDate
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        P.Id
),
PopularPosts AS (
    SELECT 
        PS.PostId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.LastActiveDate,
        PS.UpVotes - PS.DownVotes AS NetVotes,
        @rownum := @rownum + 1 AS PopularityRank
    FROM 
        RecursivePostStats PS, (SELECT @rownum := 0) r
    WHERE 
        PS.UpVotes > 0
    ORDER BY 
        PS.UpVotes DESC, PS.CommentCount DESC
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(COALESCE(B.Class, 0)) AS TotalBadgeScore,
        @userrank := @userrank + 1 AS UserRank
    FROM 
        Users U, (SELECT @userrank := 0) r
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
    ORDER BY 
        TotalBadgeScore DESC
),
FinalReport AS (
    SELECT 
        PP.PostId,
        PP.UpVotes,
        PP.DownVotes,
        PP.CommentCount,
        PP.NetVotes,
        PP.PopularityRank,
        TU.DisplayName AS TopUser,
        TU.TotalBadgeScore,
        PP.LastActiveDate
    FROM 
        PopularPosts PP
    JOIN 
        TopUsers TU ON PP.PopularityRank = TU.UserRank
)
SELECT 
    FR.PostId,
    FR.UpVotes,
    FR.DownVotes,
    FR.CommentCount,
    FR.NetVotes,
    FR.PopularityRank,
    COALESCE(FR.TopUser, 'No Users') AS TopUser,
    COALESCE(FR.TotalBadgeScore, 0) AS TotalBadgeScore,
    CASE 
        WHEN FR.LastActiveDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR) THEN 'Inactive'
        WHEN FR.LastActiveDate >= (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 YEAR) AND FR.LastActiveDate < (TIMESTAMP '2024-10-01 12:34:56' - INTERVAL 1 MONTH) THEN 'Somewhat Active'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    FinalReport FR
ORDER BY 
    FR.PopularityRank;
