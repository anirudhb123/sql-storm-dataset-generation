WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 END), 0) AS AverageUpvotes,
        COALESCE(AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 END), 0) AS AverageDownvotes,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts from the last year
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, pt.Name
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.CreationDate,
        rp.AverageUpvotes,
        rp.AverageDownvotes,
        rp.PostType
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum <= 5 -- Top 5 posts per user
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    up.UserId,
    u.DisplayName,
    SUM(tb.BadgeCount) AS TotalBadges,
    STRING_AGG(tp.Title, '; ') AS TopPostTitles,
    STRING_AGG(tp.PostType, '; ') AS PostTypes,
    SUM(tp.AverageUpvotes) AS TotalAverageUpvotes,
    SUM(tp.AverageDownvotes) AS TotalAverageDownvotes
FROM 
    UserBadges ub
JOIN 
    Users u ON u.Id = ub.UserId
JOIN 
    TopPosts tp ON tp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = u.Id
    )
GROUP BY 
    u.Id, u.DisplayName
ORDER BY 
    TotalBadges DESC, TotalAverageUpvotes DESC;
