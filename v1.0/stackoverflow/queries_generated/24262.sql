WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
QuestionDetails AS (
    SELECT 
        Q.Id AS QuestionId,
        Q.Title,
        Q.Score,
        Q.ViewCount,
        Q.CreationDate,
        COALESCE(A.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        CASE 
            WHEN A.AcceptedAnswerId IS NULL THEN 'No accepted answer'
            ELSE 'Accepted answer exists'
        END AS AnswerStatus
    FROM 
        Posts Q
    LEFT JOIN 
        Posts A ON Q.Id = A.ParentId
    WHERE 
        Q.PostTypeId = 1
),
VoteImpact AS (
    SELECT 
        P.Id AS PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS TotalUpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS TotalDownVotes,
        RANK() OVER (ORDER BY COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId IN (1, 2) 
    GROUP BY 
        P.Id
),
CteWithComputedValue AS (
    SELECT 
        U.DisplayName,
        US.UpVotes,
        US.DownVotes,
        QD.QuestionId,
        QD.Title,
        QD.Score,
        QD.ViewCount,
        QD.AcceptedAnswerId,
        CASE 
            WHEN QD.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer'
            ELSE 'No Accepted Answer'
        END AS AcceptedAnswerStatus
    FROM 
        UserStats US
    JOIN 
        QuestionDetails QD ON US.PostCount > 0
    JOIN 
        Users U ON U.Id = US.UserId
),
FinalReport AS (
    SELECT 
        CTE.*,
        COALESCE(VI.TotalUpVotes - VI.TotalDownVotes, 0) AS VoteBalance
    FROM 
        CteWithComputedValue CTE
    LEFT JOIN 
        VoteImpact VI ON CTE.QuestionId = VI.PostId
)
SELECT 
    DisplayName,
    UpVotes,
    DownVotes,
    QuestionId,
    Title,
    Score,
    ViewCount,
    AcceptedAnswerId,
    AcceptedAnswerStatus,
    VoteBalance
FROM 
    FinalReport
WHERE 
    VoteBalance > 10 
ORDER BY 
    Score DESC, ViewCount DESC NULLS LAST
LIMIT 50;

