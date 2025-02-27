WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        UpVotes,
        DownVotes,
        CommentCount,
        QuestionCount,
        RANK() OVER (ORDER BY (UpVotes - DownVotes) DESC, CommentCount DESC) AS UserRank
    FROM 
        UserActivity
),
PostEngagement AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COALESCE(COUNT(v.Id), 0) AS VoteCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        MAX(p.CreationDate) AS LastActivity
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score
),
PostDetails AS (
    SELECT 
        pe.PostId,
        pe.Title,
        pe.Score,
        pe.VoteCount,
        pe.CommentCount,
        CASE 
            WHEN pe.LastActivity IS NULL THEN 'No Activity'
            ELSE 'Active'
        END AS ActivityStatus
    FROM 
        PostEngagement pe
)
SELECT 
    u.UserId,
    u.DisplayName,
    t.UserRank,
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.VoteCount,
    pd.CommentCount,
    pd.ActivityStatus
FROM 
    TopUsers t
JOIN 
    Users u ON u.Id = t.UserId
LEFT JOIN 
    PostDetails pd ON pd.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = u.Id
    )
WHERE 
    t.UserRank <= 10
ORDER BY 
    t.UserRank, pd.Score DESC NULLS LAST;
