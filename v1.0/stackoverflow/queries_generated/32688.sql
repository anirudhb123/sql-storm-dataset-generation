WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    AND 
        p.PostTypeId IN (1, 2)  -- Questions and Answers
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        COUNT(*) AS CloseReasonCounts
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY 
        ph.PostId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS Popularity
    FROM 
        Posts p
    CROSS JOIN 
        UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags)-2), '><')) AS t(TagName)
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(*) > 5
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS BadgeScore
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
FinalReport AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.AnswerCount,
        rp.Score,
        rp.TotalBounty,
        COALESCE(cp.LastClosedDate, 'No Closure') AS LastClosedDate,
        cp.CloseReasonCounts,
        pt.Popularity AS TagPopularity,
        ur.DisplayName AS TopUser,
        ur.BadgeScore
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        PopularTags pt ON pt.Popularity = (SELECT MAX(Popularity) FROM PopularTags)
    LEFT JOIN 
        UserReputation ur ON ur.BadgeScore = (SELECT MAX(BadgeScore) FROM UserReputation)
    WHERE 
        rp.Rank = 1  -- Only consider the most recent post of each type
)
SELECT 
    *
FROM 
    FinalReport
ORDER BY 
    Score DESC, TotalBounty DESC, CreationDate DESC;
