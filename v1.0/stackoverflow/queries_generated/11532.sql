-- Performance benchmarking query for Stack Overflow schema
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.PostCount,
    us.QuestionCount,
    us.AnswerCount,
    us.UpVotes,
    us.DownVotes,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.CommentCount,
    pd.EditCount
FROM 
    UserStats us
JOIN 
    PostDetails pd ON us.UserId = pd.OwnerUserId
ORDER BY 
    us.Reputation DESC, pd.ViewCount DESC
LIMIT 100; -- Modify as necessary for benchmarking
