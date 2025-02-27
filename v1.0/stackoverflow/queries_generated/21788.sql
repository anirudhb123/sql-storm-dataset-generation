WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(PH.UserDisplayName, 'No Editor') AS LastEditorName,
        PH.CreationDate AS LastEditDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (4, 5, 6)
    WHERE 
        P.CreationDate >= (CURRENT_TIMESTAMP - INTERVAL '1 year')
),

VoteSummary AS (
    SELECT 
        V.PostId,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - 
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
), 

UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.AnswerCount,
    PS.LastEditorName,
    PS.LastEditDate,
    COALESCE(VS.UpVotes, 0) AS TotalUpVotes,
    COALESCE(VS.DownVotes, 0) AS TotalDownVotes,
    COALESCE(VS.NetVotes, 0) AS TotalNetVotes,
    UB.UserId,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    CASE 
        WHEN PS.UserPostRank = 1 THEN 'Most Recent Post'
        WHEN PS.UserPostRank <= 5 THEN 'Top 5 Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    PostStats PS
LEFT JOIN 
    VoteSummary VS ON PS.PostId = VS.PostId
LEFT JOIN 
    Users UB ON PS.OwnerUserId = UB.Id
WHERE 
    (UB.Reputation > 1000 OR UB.GoldBadges > 0)
    AND (PS.ViewCount > 100 OR PS.AnswerCount > 5)
ORDER BY 
    PS.ViewCount DESC, PS.CreationDate DESC
LIMIT 100
OFFSET 0;
