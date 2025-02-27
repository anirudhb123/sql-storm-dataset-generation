WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.UpVotes IS NOT NULL THEN p.UpVotes ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN p.DownVotes IS NOT NULL THEN p.DownVotes ELSE 0 END) AS TotalDownVotes,
        MAX(p.LastActivityDate) AS LastActivity,
        RANK() OVER (ORDER BY COUNT(DISTINCT p.Id) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        pt.Name AS PostTypeName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        MAX(h.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory h ON p.Id = h.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, pt.Name
),
TopPosts AS (
    SELECT 
        ps.*,
        RANK() OVER (ORDER BY ps.UpVotes - ps.DownVotes DESC) AS PostRank
    FROM 
        PostSummary ps
)
SELECT 
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    ua.LastActivity,
    tp.Title AS TopPostTitle,
    tp.UpVotes AS TopPostUpVotes,
    tp.DownVotes AS TopPostDownVotes,
    tp.LastEditDate
FROM 
    UserActivity ua
JOIN 
    TopPosts tp ON ua.UserId = (
        SELECT p.OwnerUserId
        FROM Posts p
        WHERE p.Title = tp.Title
        LIMIT 1
    )
WHERE 
    ua.UserRank <= 10
ORDER BY 
    ua.UserRank;
