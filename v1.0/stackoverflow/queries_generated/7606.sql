WITH PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT 
            PostId, 
            unnest(string_to_array(Tags, '><')) AS TagName
         FROM 
            Posts 
         WHERE 
            PostTypeId = 1) t ON t.PostId = p.Id
    WHERE 
        p.CreationDate >= now() - interval '1 year'
    GROUP BY 
        p.Id
), UserInteractions AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS PostsCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    WHERE 
        u.CreationDate >= now() - interval '1 year'
    GROUP BY 
        u.Id
), PostRanking AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.ViewCount,
        pi.Score,
        pi.CommentCount,
        pi.VoteCount,
        ui.DisplayName AS TopUser,
        ui.UpVotes,
        ui.DownVotes,
        ROW_NUMBER() OVER (ORDER BY pi.Score DESC, pi.ViewCount DESC) AS Rank
    FROM 
        PostInfo pi
    LEFT JOIN 
        UserInteractions ui ON pi.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = ui.UserId)
)
SELECT 
    PostId,
    Title,
    ViewCount,
    Score,
    CommentCount,
    VoteCount,
    TopUser,
    UpVotes,
    DownVotes,
    Rank
FROM 
    PostRanking
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
