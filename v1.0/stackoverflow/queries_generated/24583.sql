WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id AND v.VoteTypeId IN (8, 9)  -- Count only Bounty start and close votes
    WHERE 
        p.CreationDate >= '2022-01-01'
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        rp.*,
        pt.Name AS PostType,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVotes, 
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON pt.Id = rp.PostTypeId
    WHERE 
        rp.Rank <= 5 AND
        rp.TotalBounty > 0
),
PostStats AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.PostType,
        fp.Score,
        fp.ViewCount,
        fp.TotalBounty,
        fp.CommentCount,
        fp.UpVotes,
        fp.DownVotes,
        COUNT(DISTINCT b.Name) AS BadgeCount
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = fp.PostId)
    GROUP BY 
        fp.PostId, fp.Title, fp.PostType, fp.Score, fp.ViewCount, fp.TotalBounty, fp.CommentCount, fp.UpVotes, fp.DownVotes
),
Summary AS (
    SELECT 
        PostType,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViewCount,
        SUM(TotalBounty) AS TotalBounty,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        PostStats
    GROUP BY 
        PostType
)
SELECT 
    st.PostType,
    st.PostCount,
    st.TotalScore,
    st.AvgViewCount,
    st.TotalBounty,
    st.TotalBadges,
    CASE 
        WHEN st.PostCount = 0 THEN 'No posts available'
        ELSE ROUND(st.TotalBounty::numeric / NULLIF(st.PostCount, 0), 2)
    END AS AvgBountyPerPost,
    CASE 
        WHEN st.TotalBadges = 0 THEN 'No badges awarded'
        ELSE CONCAT('Total ', st.TotalBadges, ' badges awarded')
    END AS BadgeSummary
FROM 
    Summary st
ORDER BY 
    st.PostCount DESC, 
    st.TotalScore DESC;
