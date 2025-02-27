WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE()) -- Posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName, p.PostTypeId
),
MostCommented AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        Rank
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5 -- top 5 posts by ViewCount per PostTypeId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVotesCount -- Count of Upvotes
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT b.Id) > 0 OR SUM(v.VoteTypeId = 2) > 0
)
SELECT 
    mc.PostId,
    mc.Title,
    mc.CreationDate,
    mc.ViewCount,
    mc.OwnerDisplayName,
    mc.CommentCount,
    tu.DisplayName AS TopUserDisplayName,
    tu.BadgeCount,
    tu.UpVotesCount
FROM 
    MostCommented mc
JOIN 
    TopUsers tu ON mc.OwnerDisplayName = tu.DisplayName
ORDER BY 
    mc.ViewCount DESC, mc.CommentCount DESC;
