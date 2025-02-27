WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersGiven,
        SUM(COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) AS NetVotes,
        SUM(b.Class) AS TotalBadges,
        u.Reputation,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS QuestionRank,
        RANK() OVER (ORDER BY SUM(COALESCE(v.UpVotes, 0) - COALESCE(v.DownVotes, 0)) DESC) AS VoteRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Posts a ON u.Id = a.OwnerUserId AND a.PostTypeId = 2
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        NetVotes,
        TotalBadges,
        Reputation,
        QuestionRank,
        VoteRank
    FROM UserEngagement
    WHERE QuestionsAsked > 0 AND AnswersGiven > 0 
    ORDER BY QuestionsAsked DESC, NetVotes DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.QuestionsAsked,
    tu.AnswersGiven,
    tu.NetVotes,
    tu.TotalBadges,
    tu.Reputation,
    PH.PostHistoryTypeId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    PH.CreationDate AS HistoryCreationDate,
    PH.Comment
FROM TopUsers tu
JOIN PostHistory PH ON PH.UserId = tu.UserId
JOIN Posts P ON PH.PostId = P.Id
WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13)
ORDER BY tu.VoteRank, PH.CreationDate DESC;
