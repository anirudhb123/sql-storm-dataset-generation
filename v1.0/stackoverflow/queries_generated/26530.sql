WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, pt.Name
),
HighPerformingPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.RankByScore <= 5 OR rp.RankByViews <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Score, rp.ViewCount
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(v.BountyAmount) AS TotalBounties,
        SUM(u.UpVotes) AS TotalUpVotes,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS UserRank
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    hpp.PostId,
    hpp.Title,
    hpp.Body,
    hpp.CreationDate,
    hpp.Score,
    hpp.ViewCount,
    hpp.TagsList,
    au.DisplayName AS TopUser,
    au.TotalBounties,
    au.TotalUpVotes
FROM 
    HighPerformingPosts hpp
JOIN 
    TopUsers au ON hpp.ViewCount > 100 AND au.TotalUpVotes > 50
ORDER BY 
    hpp.Score DESC, 
    au.TotalBounties DESC
LIMIT 20;
