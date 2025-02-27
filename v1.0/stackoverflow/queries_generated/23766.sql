WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM((p.Score / NULLIF(p.ViewCount, 0)) * 100), 0) AS ScorePerView,
        DENSE_RANK() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        UpVotes, 
        DownVotes, 
        ScorePerView, 
        UserRank
    FROM 
        UserStats
    WHERE 
        UserRank <= 10
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COUNT(DISTINCT ps.UserId) AS UniqueCommenters,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        CASE 
            WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Accepted' 
            ELSE 'Not Accepted' 
        END AS AnswerStatus
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users ps ON v.UserId = ps.Id
    GROUP BY 
        p.Id
),
CommentReduction AS (
    SELECT 
        p.PostId,
        p.CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.PostId ORDER BY p.CommentCount DESC) AS CommentRank
    FROM 
        PostStats p
)

SELECT 
    u.DisplayName AS TopUser,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.CommentCount AS TotalComments,
    COALESCE(cr.CommentCount, 0) AS ReducedCommentCount,
    p.Tags AS AssociatedTags,
    u.UpVotes AS UserUpVotes,
    u.DownVotes AS UserDownVotes,
    p.AnswerStatus
FROM 
    TopUsers u
JOIN 
    Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN 
    CommentReduction cr ON p.Id = cr.PostId AND cr.CommentRank <= 5
WHERE 
    p.CreationDate > '2023-01-01' 
    AND (p.Tags IS NOT NULL OR u.DisplayName IS NOT NULL) 
ORDER BY 
    u.UpVotes DESC, 
    p.CommentCount DESC
OFFSET 10 ROWS
FETCH NEXT 10 ROWS ONLY;
