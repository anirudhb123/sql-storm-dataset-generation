
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.ClosedDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL 30 DAY
),
UserScores AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(VB.BountyAmount), 0) AS TotalBounties,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Votes VB ON U.Id = VB.UserId AND VB.VoteTypeId = 8
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        US.TotalBounties,
        (US.UpVotes - US.DownVotes) AS NetVotes
    FROM 
        Users U
    JOIN 
        UserScores US ON U.Id = US.UserId
    WHERE 
        U.Reputation > 100
    ORDER BY 
        NetVotes DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    T.DisplayName AS OwnerName,
    TU.TotalBounties,
    TU.NetVotes
FROM 
    RecentPosts RP
LEFT JOIN 
    Users T ON RP.OwnerUserId = T.Id
LEFT JOIN 
    TopUsers TU ON T.Id = TU.UserId
WHERE 
    RP.ClosedDate IS NULL OR RP.ClosedDate < CAST('2024-10-01 12:34:56' AS datetime) - INTERVAL 7 DAY
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
