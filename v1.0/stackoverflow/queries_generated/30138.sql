WITH RecursiveUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
ActivitySummary AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        UpVotes,
        DownVotes,
        (UpVotes - DownVotes) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY NetVotes DESC) AS SummaryRank
    FROM 
        RecursiveUserActivity
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        NetVotes,
        SummaryRank
    FROM 
        ActivitySummary
    WHERE 
        SummaryRank <= 10
),
RecentPostEdits AS (
    SELECT 
        ph.UserDisplayName,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        p.Title,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS EditRank
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
RecentTopEdits AS (
    SELECT 
        UserDisplayName,
        PostId,
        Title,
        CreationDate,
        Comment
    FROM 
        RecentPostEdits
    WHERE 
        EditRank = 1
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    rpe.Title AS RecentEditedPostTitle,
    rpe.CreationDate AS RecentEditDate,
    rpe.Comment AS RecentEditComment
FROM 
    TopUsers tu
LEFT JOIN 
    RecentTopEdits rpe ON tu.UserId = rpe.UserId
ORDER BY 
    tu.Reputation DESC, 
    rpe.RecentEditDate DESC;
