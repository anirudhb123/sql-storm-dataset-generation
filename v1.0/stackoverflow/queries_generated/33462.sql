WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) OVER (PARTITION BY p.Id) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) OVER (PARTITION BY p.Id) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
QualifiedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerReputation,
        rp.Rank,
        rp.UpvoteCount,
        rp.DownvoteCount,
        (rp.UpvoteCount - rp.DownvoteCount) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),
AggregatedData AS (
    SELECT 
        qp.OwnerReputation,
        AVG(qp.NetVotes) AS AvgNetVotes,
        COUNT(DISTINCT qp.PostId) AS TotalPosts,
        MAX(qp.Score) AS MaxScore
    FROM 
        QualifiedPosts qp
    GROUP BY 
        qp.OwnerReputation
),
FinalResults AS (
    SELECT 
        ad.OwnerReputation,
        ad.AvgNetVotes,
        ad.TotalPosts,
        ad.MaxScore,
        CASE 
            WHEN ad.AvgNetVotes IS NULL THEN 'No Data'
            WHEN ad.AvgNetVotes < 0 THEN 'Needs Improvement'
            ELSE 'Good Engagement'
        END AS EngagementStatus
    FROM 
        AggregatedData ad
)
SELECT 
    COALESCE(NULLIF(f.OwnerReputation, 0), 'Unknown') AS ReputationStatus,
    f.AvgNetVotes,
    f.TotalPosts,
    f.MaxScore,
    f.EngagementStatus
FROM 
    FinalResults f
ORDER BY 
    f.AvgNetVotes DESC NULLS LAST;
