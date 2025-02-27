
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Body,
        u.DisplayName AS OwnerName,
        @row_number := IF(@prev_post_type = p.PostTypeId, @row_number + 1, 1) AS RankByDate,
        @prev_post_type := p.PostTypeId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type := NULL) AS vars
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Body, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Body,
        rp.OwnerName,
        rp.RankByDate,
        CASE 
            WHEN rp.Score IS NULL THEN 'No Score' 
            WHEN rp.Score > 0 THEN 'Positive Score' 
            ELSE 'Negative Score' 
        END AS ScoreCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByDate <= 5
),
PostViewStats AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId
    GROUP BY 
        fp.PostId, fp.Title, fp.CreationDate, fp.ViewCount
)
SELECT 
    pvs.PostId,
    pvs.Title,
    pvs.CreationDate,
    pvs.ViewCount,
    pvs.TotalComments,
    (pvs.TotalUpVotes - pvs.TotalDownVotes) AS NetVotes,
    CASE 
        WHEN pvs.ViewCount > 1000 THEN 'High Engagement'
        WHEN pvs.ViewCount BETWEEN 500 AND 1000 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM 
    PostViewStats pvs
ORDER BY 
    NetVotes DESC, 
    pvs.ViewCount DESC 
LIMIT 10;
