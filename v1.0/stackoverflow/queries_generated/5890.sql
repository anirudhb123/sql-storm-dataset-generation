WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(b.Class) AS TotalBadges,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalBadges,
        UpVotes - DownVotes AS VoteBalance
    FROM 
        UserStatistics
    ORDER BY 
        VoteBalance DESC, PostCount DESC
    LIMIT 10
),
PostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        pc.UserId AS AuthorId,
        pc.UserDisplayName AS AuthorDisplayName,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        TopUsers tu ON tu.UserId = p.OwnerUserId
    WHERE 
        p.LastActivityDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.LastActivityDate, pc.UserId, pc.UserDisplayName, p.Score, p.ViewCount
)
SELECT 
    t.DisplayName AS TopContributor,
    pd.Title AS RecentPostTitle,
    pd.CreationDate AS PostCreatedDate,
    pd.LastActivityDate AS PostLastActivityDate,
    pd.Score AS PostScore,
    pd.ViewCount AS PostViewCount,
    pd.CommentCount AS PostCommentCount
FROM 
    TopUsers t
JOIN 
    PostData pd ON t.UserId = pd.AuthorId
ORDER BY 
    t.VoteBalance DESC, pd.LastActivityDate DESC;
