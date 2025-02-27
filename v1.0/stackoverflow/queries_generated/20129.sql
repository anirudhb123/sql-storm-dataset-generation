WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) -- Questions and Answers only
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Only Gold badges
    GROUP BY 
        b.UserId
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(pb.BadgeCount, 0) AS GoldBadges,
    p.Title,
    p.CreationDate,
    p.Score,
    pv.TotalVotes,
    pv.UpVotes,
    pv.DownVotes,
    rp.PostRank
FROM 
    Users u
LEFT JOIN 
    UserBadges pb ON u.Id = pb.UserId
JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    (pv.UpVotes - pv.DownVotes) / NULLIF(pv.TotalVotes, 0) > 0.5 -- High net score
ORDER BY 
    GoldBadges DESC, 
    rp.PostRank ASC
LIMIT 10;

### Explanation:
1. **CTE `RankedPosts`:** This captures posts made in the past year and ranks them by their score for each user.
2. **CTE `PostVotes`:** This aggregates vote data for posts, calculating total votes, upvotes, and downvotes.
3. **CTE `UserBadges`:** This counts Gold badges received by users.
4. **Final Selection:** The query selects users along with their details, including posts, voted information, and ranks. The output focuses on users whose net votes are significantly positive.
5. The use of `COALESCE` accounts for users without badges, ensuring they still appear with a count of zero badges.
6. The predicates involve calculating a net score while handling potential division by zero using `NULLIF`.
7. The final output is ordered by the number of gold badges and post rank, ensuring that the most successful users by badge count and post performance are listed.
