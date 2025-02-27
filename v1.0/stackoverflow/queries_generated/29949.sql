WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.OwnerUserId,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11, 12)) AS CloseRevisions,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON t.Id IN (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><'))::int[])
                           )
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        p.Id
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes - u.DownVotes) AS VoteBalance,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
    ORDER BY 
        VoteBalance DESC, GoldBadges DESC, SilverBadges DESC, BronzeBadges DESC
    LIMIT 10
)

SELECT 
    ru.DisplayName AS TopUser,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS PostDate,
    rp.ViewCount AS PostViews,
    rp.Score AS PostScore,
    rp.CommentsCount AS PostComments,
    rp.CloseRevisions AS PostCloseRevisions,
    rp.Tags AS PostTags
FROM 
    RankedPosts rp
JOIN 
    TopUsers ru ON rp.OwnerUserId = ru.UserId
WHERE 
    rp.rn = 1 -- Get the most recent question for each top user
ORDER BY 
    rp.CreationDate DESC;

