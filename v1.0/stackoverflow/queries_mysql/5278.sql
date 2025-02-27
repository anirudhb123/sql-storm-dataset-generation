
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        @row_num := IF(@post_type_id = p.PostTypeId, @row_num + 1, 1) AS Rank,
        @post_type_id := p.PostTypeId
    FROM 
        Posts p, (SELECT @row_num := 0, @post_type_id := NULL) AS init
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR 
        AND p.Score IS NOT NULL
    ORDER BY 
        p.PostTypeId, p.Score DESC
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId    
    GROUP BY 
        p.Id
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        tu.DisplayName AS Owner,
        rp.Score,
        rp.ViewCount,
        pv.Upvotes,
        pv.Downvotes,
        CASE WHEN rp.Rank <= 10 THEN 'Top 10' ELSE 'Other' END AS RankCategory
    FROM 
        RankedPosts rp
    JOIN 
        TopUsers tu ON rp.OwnerUserId = tu.UserId
    LEFT JOIN 
        PostVotes pv ON rp.PostId = pv.PostId
)
SELECT 
    RankCategory,
    COUNT(*) AS PostCount,
    AVG(Score) AS AverageScore,
    AVG(ViewCount) AS AverageViews,
    SUM(Upvotes) AS TotalUpvotes,
    SUM(Downvotes) AS TotalDownvotes
FROM 
    PostDetails
GROUP BY 
    RankCategory
ORDER BY 
    RankCategory;
