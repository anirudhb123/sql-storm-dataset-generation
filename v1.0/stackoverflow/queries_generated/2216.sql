WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(VoteTypeId = 3), 0) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
QuestionDetails AS (
    SELECT 
        P.Id AS QuestionId,
        P.Title,
        P.CreationDate,
        Q.OwnerUserId,
        COUNT(A.Id) AS AnswerCount,
        COALESCE(MAX(V.CreationDate), '1900-01-01') AS LastVoteDate
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title, P.CreationDate, Q.OwnerUserId
),
VotingStats AS (
    SELECT 
        Q.QuestionId,
        COUNT(V.Id) AS TotalVotes,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        AVG(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes
    FROM 
        QuestionDetails Q
    LEFT JOIN 
        Votes V ON Q.QuestionId = V.PostId
    GROUP BY 
        Q.QuestionId
)
SELECT 
    UD.UserId,
    UD.DisplayName,
    UD.Reputation,
    QD.QuestionId,
    QD.Title,
    QD.CreationDate,
    QS.TotalVotes,
    QS.AvgUpVotes,
    QS.AvgDownVotes,
    CASE 
        WHEN QS.TotalVotes = 0 THEN 'No votes yet'
        ELSE 'Has votes'
    END AS VoteStatus,
    COALESCE(UPD.VoteDate, 'Never voted') AS LastVoteStatus
FROM 
    UserReputation UD
LEFT JOIN 
    QuestionDetails QD ON UD.UserId = QD.OwnerUserId
LEFT JOIN 
    VotingStats QS ON QD.QuestionId = QS.QuestionId
LEFT JOIN (
    SELECT 
        V.UserId,
        MAX(V.CreationDate) AS VoteDate
    FROM 
        Votes V
    GROUP BY 
        V.UserId
) UPD ON UD.UserId = UPD.UserId
WHERE 
    UD.Reputation > 1000
ORDER BY 
    UD.Reputation DESC, QD.CreationDate DESC
LIMIT 50;
