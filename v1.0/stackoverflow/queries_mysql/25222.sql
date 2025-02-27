
WITH UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        DATE_FORMAT(u.CreationDate, '%Y-%m-01') AS RegistrationMonth
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, DATE_FORMAT(u.CreationDate, '%Y-%m-01')
),

RecentPostHistory AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Text,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL 1 YEAR
)

SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.PostCount,
    ue.QuestionCount,
    ue.AnswerCount,
    ue.CommentCount,
    ue.UpVotes,
    ue.DownVotes,
    COUNT(CASE WHEN rph.rn = 1 THEN rph.PostId END) AS RecentActionsCount,
    GROUP_CONCAT(DISTINCT CONCAT(pt.Name, ': ', rph.Text) ORDER BY pt.Name SEPARATOR '; ') AS RecentPostsHistory
FROM 
    UserEngagement ue
LEFT JOIN 
    RecentPostHistory rph ON ue.UserId = rph.UserId
LEFT JOIN 
    PostTypes pt ON rph.PostHistoryTypeId = pt.Id
GROUP BY 
    ue.UserId, ue.DisplayName, ue.PostCount, ue.QuestionCount, ue.AnswerCount, ue.CommentCount, ue.UpVotes, ue.DownVotes
ORDER BY 
    ue.PostCount DESC, ue.DisplayName;
