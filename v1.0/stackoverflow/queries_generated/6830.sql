WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(vote.TypeId = 2) AS TotalUpVotes,
        SUM(vote.TypeId = 3) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes vote ON u.Id = vote.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpVotes - TotalDownVotes AS NetScore
    FROM 
        UserStats
    ORDER BY 
        NetScore DESC 
    LIMIT 10
),
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        t.TagName,
        COALESCE(SUM(v.voteTypeId = 2), 0) AS UpVotes,
        COALESCE(SUM(v.voteTypeId = 3), 0) AS DownVotes,
        COALESCE(SUM(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        PostLinks pl ON p.Id = pl.PostId
    LEFT JOIN 
        Tags t ON pl.RelatedPostId = t.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, t.TagName
),
FinalOutput AS (
    SELECT 
        tu.DisplayName,
        tu.TotalPosts,
        tu.TotalComments,
        pi.PostId,
        pi.Title,
        pi.CreationDate,
        pi.TagName,
        pi.UpVotes,
        pi.DownVotes,
        pi.CommentCount
    FROM 
        TopUsers tu
    JOIN 
        PostInfo pi ON tu.UserId = pi.OwnerUserId
)
SELECT 
    * 
FROM 
    FinalOutput
ORDER BY 
    TotalPosts DESC, UpVotes DESC;
