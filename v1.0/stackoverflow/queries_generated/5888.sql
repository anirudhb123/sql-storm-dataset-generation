WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT ph.Id) AS PostHistoryEdits
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
PostRankings AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(vs.UpVotes, 0) AS UpVotes,
        COALESCE(vs.DownVotes, 0) AS DownVotes,
        COALESCE(cs.CommentScore, 0) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM 
            Votes 
        GROUP BY 
            PostId
    ) vs ON p.Id = vs.PostId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(Id) AS CommentScore
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cs ON p.Id = cs.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.UpVotes,
    us.DownVotes,
    us.TotalPosts,
    us.PostHistoryEdits,
    tr.TagName,
    tr.PostCount,
    tr.TotalViews,
    pr.PostId,
    pr.Title,
    pr.CreationDate,
    pr.UpVotes AS PostUpVotes,
    pr.DownVotes AS PostDownVotes,
    pr.CommentCount,
    pr.PostRank
FROM 
    UserStats us
JOIN 
    TagStats tr ON us.TotalPosts > 0
JOIN 
    PostRankings pr ON pr.UpVotes >= 10
ORDER BY 
    us.Reputation DESC, pr.PostRank;
